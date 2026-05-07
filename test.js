import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from "dotenv";

dotenv.config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

async function run() {

    const model = genAI.getGenerativeModel({
        model: "gemini-2.5-flash-lite"
    });

    const result = await model.generateContent(
        "Explain REST API in one sentence"
    );

    console.log(result.response.text());
}

run();