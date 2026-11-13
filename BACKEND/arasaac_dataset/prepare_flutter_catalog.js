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

// Classe gramatical para a chave de cores Fitzgerald (RF03), derivada das
// tags do ARASAAC. A ordem das regras importa (ex.: "sim" e "não" vêm com a
// tag "verb", mas na CAA são palavras sociais).
const SOCIAL_WORDS = new Set([
  'sim', 'não', 'oi', 'olá', 'tchau', 'obrigado', 'obrigada', 'por favor',
  'desculpa', 'bom dia', 'boa tarde', 'boa noite',
]);
const DESCRIPTOR_WORDS = new Set([
  'mais', 'menos', 'muito', 'pouco', 'grande', 'pequeno',
]);
function fitzgerald(pictogram) {
  const tags = new Set([...(pictogram.tags ?? []), ...(pictogram.categorias ?? [])]);
  const word = pictogram.palavra.trim().toLocaleLowerCase('pt-BR');
  const hasAny = (...names) => names.some((name) => tags.has(name));
  if (DESCRIPTOR_WORDS.has(word)) return 'descritor';
  if (SOCIAL_WORDS.has(word) ||
      hasAny('polite set expression', 'expression', 'interjection')) return 'social';
  if (hasAny('interrogative pronoun', 'preposition', 'article', 'conjunction')) return 'estrutural';
  if (hasAny('personal pronoun', 'pronoun')) return 'pessoa';
  if (tags.has('verb')) return 'verbo';
  if (hasAny('adjective', 'qualifying adjective', 'adverb', 'feeling', 'emotion', 'color')) return 'descritor';
  if (hasAny('person', 'family')) return 'pessoa';
  return 'substantivo';
}

const catalogPictograms = Object.values(pictograms)
  .filter((pictogram) =>
    categories.some((category) =>
      category.pictogramIds.includes(pictogram.id),
    ),
  )
  .map((pictogram) => ({
    id: String(pictogram.id),
    label: pictogram.palavra,
    fitz: fitzgerald(pictogram),
  }));
const availableIds = new Set(catalogPictograms.map((pictogram) => pictogram.id));
const principalIds = principalWords.map(findPictogram);
for (const id of principalIds) {
  if (!availableIds.has(id)) {
    throw new Error(`Pictograma da prancha Principal fora das categorias: ${id}`);
  }
}

const manifest = {
  version: 'arasaac-2026-11-full-v3',
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
