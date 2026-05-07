import express from 'express'
import { Octokit } from 'octokit'
//import { GoogleGenAI } from '@google/genai'
import { GoogleGenerativeAI } from '@google/generative-ai'
import dotenv from 'dotenv'

dotenv.config()

const app = express();
app.use(express.json());

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });

app.post('/webhook', async (req, res) => {
    const { action, pull_request, repository } = req.body;

    if(action == 'opened' || action == 'synchronize'){
        const owner = repository.owner.login;
        const repo = repository.name;
        const pullNumber = pull_request.number;

        try{
            console.log(`Processing PR #${pullNumber} ... `);

            const { data: diff } = await octokit.rest.pulls.get({
                owner,
                repo,
                pull_number: pullNumber,
                mediaType: {format:'diff'}
            });
 
            if (!diff || diff.length < 10) {
               console.log("Diff is too small to summarize.");
               return; 
}

            const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash-lite" });
            const prompt = `You are a senior software engineer. Summarize these code changes into 3 bullet points for a PR human reviewer: \n\n ${diff} `;

            // Log this to see if the request actually goes out
            console.log("Sending diff to Gemini...");

            const result = await model.generateContent(prompt);
            const summary = result.response.text();

            await octokit.rest.issues.createComment({
                owner,
                repo,
                issue_number: pullNumber,
                body: `### AI Code Summary\n\n ${summary}`,
            });

            console.log('Summary posted successfully!')

        }catch(e){
            console.log('Error processing PR', e)
            console.error(e.message);
        }
    }
    res.status(200).send('OK');
});

app.listen(process.env.PORT, () => {
    console.log(`Bot is listening on port ${process.env.PORT}`);
})