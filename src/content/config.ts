import { defineCollection, z } from "astro:content";

const blog = defineCollection({
	type: "content",
	schema: z
		.object({
			title: z.string(),
			description: z.string().optional().default(""),
			pubDate: z.coerce.date(),
			updatedDate: z.coerce.date().optional(),
			heroImage: z.string().optional().default(""),
			tags: z.array(z.string()).optional().default([]),
			category: z.string().optional().nullable().default("技术笔记"),
			subtitle: z.unknown().optional(),
			author: z.string().optional(),
			draft: z.boolean().optional().default(false),
			lang: z.string().optional().default(""),
		})
		.passthrough()
		.transform((data) => ({
			...data,
			published: data.pubDate,
			updated: data.updatedDate,
			image: data.heroImage,
			tags:
				data.tags.length > 0
					? data.tags
					: Array.isArray(data.subtitle)
						? data.subtitle
						: [],
			category: data.category,
			prevTitle: "",
			prevSlug: "",
			nextTitle: "",
			nextSlug: "",
		})),
});

const resume = defineCollection({
	type: "content",
	schema: z.object({
		title: z.string(),
		description: z.string(),
		pubDate: z.coerce.date(),
		updatedDate: z.coerce.date().optional(),
		heroImage: z.string().optional(),
	}),
});

export const collections = { blog, resume };
