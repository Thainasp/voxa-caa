const fs = require('node:fs');
const path = require('node:path');

const sourceDirectory = __dirname;
const projectRoot = path.resolve(sourceDirectory, '..', '..');
const outputFile = path.join(
  projectRoot,
  'FRONTEND',
  'voxa',
  'assets',
  'arasaac',
  'catalogo_inicial.json',
);
const source = JSON.parse(
  fs.readFileSync(path.join(sourceDirectory, 'catalogo.json'), 'utf8'),
);
const pictograms = source.pictogramas;
const categories = source.categorias.map((category, order) => ({
  key: `arasaac:${category.chave}`,
  label: category.texto,
  parentKey: category.pai ? `arasaac:${category.pai}` : null,
  order,
  pictogramIds: category.pictogramas,
}));

function findPictogram(word) {
  const normalized = word.trim().toLocaleLowerCase('pt-BR');
  const pictogram = Object.values(pictograms).find((candidate) =>
    [candidate.palavra, ...(candidate.palavras ?? [])].some(
      (candidateWord) =>
        candidateWord.toLocaleLowerCase('pt-BR') === normalized,
    ),
  );
  if (!pictogram) throw new Error(`Palavra ARASAAC não encontrada: ${word}`);
  return String(pictogram.id);
}

const principalWords = [
  'eu',
  'você',
  'sim',
  'não',
  'querer',
  'mais',
  'ajuda',
  'comer',
  'beber',
  'água',
  'ir',
  'banheiro',
  'mãe',
  'pai',
  'parar',
  'brincar',
  'dormir',
  'por favor',
  'obrigado',
  'onde',
  'casa',
  'escola',
  'esperar',
  'triste',
];

const catalogPictograms = Object.values(pictograms)
  .filter((pictogram) =>
    categories.some((category) =>
      category.pictogramIds.includes(pictogram.id),
    ),
  )
  .map((pictogram) => ({
    id: String(pictogram.id),
    label: pictogram.palavra,
  }));
const availableIds = new Set(catalogPictograms.map((pictogram) => pictogram.id));
const principalIds = principalWords.map(findPictogram);
for (const id of principalIds) {
  if (!availableIds.has(id)) {
    throw new Error(`Pictograma da prancha Principal fora das categorias: ${id}`);
  }
}

const manifest = {
  version: 'arasaac-2026-11-full-v2',
  source: source.fonte,
  license: source.licenca,
  principalIds,
  categories,
  pictograms: catalogPictograms,
};

fs.writeFileSync(outputFile, `${JSON.stringify(manifest)}\n`);
console.log(
  `Catálogo completo gerado: ${categories.length} categorias, ` +
    `${catalogPictograms.length} pictogramas e ` +
    `${categories.reduce(
      (total, category) => total + category.pictogramIds.length,
      principalIds.length,
    )} associações.`,
);
