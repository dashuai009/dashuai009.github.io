import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import { typst } from 'astro-typst';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
	site: 'https://dashuai009.github.io',
	integrations: [mdx(), sitemap(), typst()],
	base: '/',
	vite:{
		ssr: {
			external: ["@myriaddreamin/typst-ts-node-compiler"],
		}
	}
});
