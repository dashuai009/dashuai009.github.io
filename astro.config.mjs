import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import { typst } from 'astro-typst';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
	site: 'https://dashuai009.github.io',
	integrations: [mdx(), sitemap(), typst({
      options: {
        remPx: 14,
      },
      target: (id) => {
        // console.debug(`Detecting ${id}`);
        // if (id.endsWith('.html.typ') || id.includes('/html/'))
          return "html";
        // return "svg";
      },
    })],
	vite:{
		ssr: {
			external: ["@myriaddreamin/typst-ts-node-compiler"],
		}
	}
});
