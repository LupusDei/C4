const presets = [
  // --- Cinematic ---
  {
    name: 'Film Noir',
    description: 'Classic 1940s noir atmosphere with dramatic shadows and high contrast',
    prompt_modifier: 'high contrast black and white, dramatic shadows, venetian blind lighting, 1940s noir atmosphere, chiaroscuro, film grain, moody, detective genre aesthetic',
    category: 'cinematic',
  },
  {
    name: 'Golden Hour Cinema',
    description: 'Warm, golden sunlight with cinematic depth of field',
    prompt_modifier: 'golden hour warm sunlight, cinematic lens flare, shallow depth of field, soft diffused glow, warm amber tones, anamorphic bokeh, magic hour lighting',
    category: 'cinematic',
  },
  {
    name: 'Anamorphic Widescreen',
    description: 'Ultra-wide cinematic framing with lens distortion',
    prompt_modifier: 'anamorphic widescreen 2.39:1 aspect ratio, horizontal lens flare, oval bokeh, cinematic color grading, blockbuster framing, slight barrel distortion',
    category: 'cinematic',
  },
  {
    name: 'Vintage 35mm',
    description: 'Authentic 35mm film look with natural grain and color',
    prompt_modifier: 'shot on 35mm film, natural film grain, slightly desaturated colors, organic texture, Kodak Portra color palette, soft halation, analog warmth',
    category: 'cinematic',
  },
  {
    name: 'Blockbuster Epic',
    description: 'Large-scale epic framing with dramatic lighting',
    prompt_modifier: 'epic wide shot, dramatic volumetric lighting, grand scale, cinematic composition, deep shadows, rich saturated colors, IMAX quality, heroic low angle',
    category: 'cinematic',
  },
  {
    name: 'Documentary Realism',
    description: 'Raw, authentic documentary-style look',
    prompt_modifier: 'documentary style, natural available lighting, handheld camera feel, authentic and raw, muted color palette, realistic grain, candid composition, photojournalistic',
    category: 'cinematic',
  },

  // --- Photography ---
  {
    name: 'Studio Portrait',
    description: 'Professional studio lighting with clean backgrounds',
    prompt_modifier: 'professional studio lighting, Rembrandt lighting pattern, clean background, sharp focus on subject, soft skin tones, catchlight in eyes, 85mm portrait lens',
    category: 'photography',
  },
  {
    name: 'Street Photography',
    description: 'Candid urban scenes with gritty authenticity',
    prompt_modifier: 'street photography, candid moment, urban environment, natural light, high contrast black and white option, decisive moment, 35mm lens perspective, gritty authentic',
    category: 'photography',
  },
  {
    name: 'Aerial Drone',
    description: 'Bird\'s eye view with stunning aerial perspective',
    prompt_modifier: 'aerial drone photography, bird\'s eye view, top-down perspective, stunning landscape, high altitude, geometric patterns, sweeping vista, DJI quality',
    category: 'photography',
  },
  {
    name: 'Macro Close-Up',
    description: 'Extreme close-up revealing intricate details',
    prompt_modifier: 'macro photography, extreme close-up, shallow depth of field, intricate details revealed, water droplets, fine textures, 100mm macro lens, ring light illumination',
    category: 'photography',
  },
  {
    name: 'Fashion Editorial',
    description: 'High-fashion editorial look with dramatic styling',
    prompt_modifier: 'high fashion editorial, Vogue magazine quality, dramatic pose, studio or location lighting, bold styling, beauty dish lighting, fashion photography, haute couture aesthetic',
    category: 'photography',
  },
  {
    name: 'Landscape Golden Hour',
    description: 'Breathtaking landscapes bathed in golden light',
    prompt_modifier: 'landscape photography, golden hour, sweeping vista, foreground interest, leading lines, dramatic sky, rich warm tones, sharp front to back, f/11 deep focus',
    category: 'photography',
  },

  // --- Illustration ---
  {
    name: 'Anime/Manga',
    description: 'Japanese anime and manga art style',
    prompt_modifier: 'anime art style, manga illustration, cel shading, vibrant colors, large expressive eyes, clean linework, Japanese animation aesthetic, dynamic pose',
    category: 'illustration',
  },
  {
    name: 'Watercolor',
    description: 'Soft, flowing watercolor painting effect',
    prompt_modifier: 'watercolor painting, soft flowing washes, wet on wet technique, visible paper texture, gentle color bleeding, transparent layers, delicate brushstrokes, artistic imperfection',
    category: 'illustration',
  },
  {
    name: 'Comic Book',
    description: 'Bold comic book style with halftone patterns',
    prompt_modifier: 'comic book art style, bold ink outlines, halftone dot pattern, vivid primary colors, dynamic action panels, Ben-Day dots, superhero comic aesthetic, speech bubble ready',
    category: 'illustration',
  },
  {
    name: 'Children\'s Book',
    description: 'Warm, whimsical children\'s book illustration style',
    prompt_modifier: 'children\'s book illustration, warm and whimsical, soft rounded shapes, gentle pastel colors, storybook quality, friendly characters, hand-painted feel, cozy atmosphere',
    category: 'illustration',
  },
  {
    name: 'Concept Art',
    description: 'Professional concept art for games and film',
    prompt_modifier: 'concept art, professional game or film design, painterly brushstrokes, atmospheric perspective, dramatic lighting, detailed environment design, matte painting quality, industry standard',
    category: 'illustration',
  },
  {
    name: 'Ink Drawing',
    description: 'Detailed ink illustration with cross-hatching',
    prompt_modifier: 'ink drawing, fine pen illustration, cross-hatching technique, black ink on white paper, detailed linework, stippling, woodcut inspired, high contrast monochrome',
    category: 'illustration',
  },

  // --- Digital Art ---
  {
    name: 'Neon Cyberpunk',
    description: 'Futuristic neon-lit cyberpunk aesthetic',
    prompt_modifier: 'neon-lit cityscape, cyberpunk aesthetic, rain-slicked streets, holographic displays, purple and cyan color palette, blade runner atmosphere, futuristic technology, glowing signage',
    category: 'digital-art',
  },
  {
    name: 'Vaporwave',
    description: 'Retro-futuristic vaporwave aesthetic',
    prompt_modifier: 'vaporwave aesthetic, pastel pink and teal, Greek statue elements, retro computer graphics, palm trees, sunset gradient, 90s internet nostalgia, glitch elements, Japanese text',
    category: 'digital-art',
  },
  {
    name: 'Low Poly 3D',
    description: 'Geometric low-polygon 3D art style',
    prompt_modifier: 'low poly 3D art, geometric faceted surfaces, minimal polygon count, flat shading, clean edges, colorful triangulated mesh, isometric view, modern minimalist 3D',
    category: 'digital-art',
  },
  {
    name: 'Pixel Art',
    description: 'Retro pixel art with limited color palette',
    prompt_modifier: 'pixel art, 16-bit retro gaming style, limited color palette, crisp pixel edges, nostalgic video game aesthetic, sprite art quality, dithering technique, chiptune era',
    category: 'digital-art',
  },
  {
    name: 'Synthwave',
    description: 'Retro 80s synthwave visual style',
    prompt_modifier: 'synthwave aesthetic, retro 80s grid landscape, neon sunset gradient, chrome text, outrun style, laser grid horizon, retrowave, magenta and electric blue palette',
    category: 'digital-art',
  },
  {
    name: 'Glitch Art',
    description: 'Digital glitch and data corruption aesthetic',
    prompt_modifier: 'glitch art, digital corruption, RGB channel splitting, data moshing, scan lines, pixel sorting, broken digital signal, VHS tracking errors, chromatic aberration',
    category: 'digital-art',
  },

  // --- Retro ---
  {
    name: '80s Retro',
    description: 'Vibrant 1980s pop culture aesthetic',
    prompt_modifier: '1980s retro aesthetic, vibrant neon colors, Memphis design patterns, geometric shapes, chrome and gradient, pop culture style, cassette tape era, bold and loud',
    category: 'retro',
  },
  {
    name: 'Vintage Polaroid',
    description: 'Instant film look with faded colors and white borders',
    prompt_modifier: 'vintage Polaroid instant film, faded washed-out colors, white border frame, slight overexposure, warm color cast, nostalgic imperfect quality, square format, light leak',
    category: 'retro',
  },
  {
    name: 'Art Deco',
    description: 'Elegant 1920s Art Deco design aesthetic',
    prompt_modifier: 'Art Deco style, 1920s elegance, geometric symmetry, gold and black palette, ornate decorative patterns, Gatsby era luxury, streamlined forms, architectural grandeur',
    category: 'retro',
  },
  {
    name: 'Psychedelic 60s',
    description: 'Trippy 1960s psychedelic art style',
    prompt_modifier: 'psychedelic 1960s art, trippy swirling patterns, vibrant rainbow colors, paisley and fractal designs, tie-dye aesthetic, flower power, Peter Max inspired, kaleidoscopic',
    category: 'retro',
  },
  {
    name: 'VHS Aesthetic',
    description: 'Analog VHS tape recording look',
    prompt_modifier: 'VHS aesthetic, analog video recording, scan lines, tracking distortion, washed-out colors, date stamp overlay, magnetic tape artifacts, retro home video quality, CRT screen',
    category: 'retro',
  },

  // --- Abstract ---
  {
    name: 'Minimalist',
    description: 'Clean, minimal composition with negative space',
    prompt_modifier: 'minimalist design, clean composition, generous negative space, limited color palette, simple geometric forms, less is more philosophy, modern and refined, Bauhaus inspired',
    category: 'abstract',
  },
  {
    name: 'Geometric',
    description: 'Bold geometric shapes and patterns',
    prompt_modifier: 'geometric abstract art, bold shapes and patterns, precise lines, vibrant color blocks, mathematical harmony, tessellation, Mondrian inspired, structured composition',
    category: 'abstract',
  },
  {
    name: 'Surrealist',
    description: 'Dreamlike surrealist imagery inspired by Dali and Magritte',
    prompt_modifier: 'surrealist art, dreamlike impossible scene, melting forms, unexpected juxtapositions, Dali and Magritte inspired, subconscious imagery, hyperreal details in unreal settings',
    category: 'abstract',
  },
  {
    name: 'Fluid Art',
    description: 'Flowing organic abstract with marble-like patterns',
    prompt_modifier: 'fluid art, acrylic pour painting, flowing organic forms, marble-like swirls, iridescent color mixing, cell patterns, glossy finish, abstract expressionism, liquid movement',
    category: 'abstract',
  },
];

export async function seed(knex) {
  // Only insert if table is empty (don't overwrite on re-seed)
  const existing = await knex('style_presets').where('is_custom', false).count('* as count').first();
  if (parseInt(existing.count, 10) > 0) return;

  await knex('style_presets').insert(
    presets.map((p) => ({
      ...p,
      is_custom: false,
      user_id: null,
    })),
  );
}
