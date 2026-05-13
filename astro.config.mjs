// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	site: 'https://wanggang316.github.io',
	base: '/agent-engineer',
	integrations: [
		starlight({
			title: 'Agent Engineer',
			description: 'A course for software engineers on AI agents.',
			social: [
				{
					icon: 'github',
					label: 'GitHub',
					href: 'https://github.com/google-gemini/agent-engineer',
				},
			],
			defaultLocale: 'root',
			locales: {
				root: { label: 'English', lang: 'en' },
				'zh-cn': { label: '简体中文', lang: 'zh-CN' },
			},
			sidebar: [
				{
					label: 'Part 1: Fundamentals',
					translations: { 'zh-CN': '第一部分：基础' },
					items: [
						{ slug: '01-what-are-ai-agents' },
						{ slug: '02-how-agents-think' },
						{ slug: '03-tools-giving-agents-hands' },
						{ slug: '04-agentic-design-patterns' },
						{ slug: '05-memory-and-context' },
						{ slug: '06-planning-and-reasoning' },
						{ slug: '07-multi-agent-systems' },
						{ slug: '08-agentic-rag' },
						{ slug: '09-evaluating-and-testing-agents' },
						{ slug: '10-guardrails-and-safety' },
					],
				},
				{
					label: 'Part 2: Building & Shipping',
					translations: { 'zh-CN': '第二部分：构建与交付' },
					items: [
						{ slug: '11-from-prototype-to-production' },
						{ slug: '12-getting-started-with-vertex-and-adk' },
						{ slug: '13-building-your-first-agent' },
						{ slug: '14-agent-protocols-mcp-and-a2a' },
					],
				},
				{
					label: 'Part 3: Deep Dives',
					translations: { 'zh-CN': '第三部分：专题深入' },
					items: [
						{ slug: '15-agents-md' },
						{ slug: '16-mcp-deep-dive' },
						{ slug: '17-agent-skills' },
						{ slug: '18-orchestrators' },
						{ slug: '19-where-to-go-from-here' },
					],
				},
			],
		}),
	],
});
