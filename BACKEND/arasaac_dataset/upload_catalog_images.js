const fs = require('node:fs');
const path = require('node:path');

const supabaseUrl = process.env.SUPABASE_URL?.replace(/\/+$/, '');
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!supabaseUrl || !serviceRoleKey) {
  throw new Error(
    'Defina SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY no ambiente. ' +
      'Não coloque a chave no código nem a envie ao Git.',
  );
}
if (serviceRoleKey.startsWith('sb_secret_')) {
  throw new Error(
    'O Storage exige a chave JWT legada service_role no cabeçalho Authorization. ' +
      'A chave Secret sb_secret_ não é aceita por este uploader.',
  );
}

const sourceDirectory = __dirname;
const catalog = JSON.parse(
  fs.readFileSync(path.join(sourceDirectory, 'catalogo.json'), 'utf8'),
);
const ids = [
  ...new Set(catalog.categorias.flatMap((category) => category.pictogramas)),
];
const bucket = 'arasaac-catalog';
const headers = {
  apikey: serviceRoleKey,
  Authorization: `Bearer ${serviceRoleKey}`,
};

async function ensureBucket() {
  const response = await fetch(`${supabaseUrl}/storage/v1/bucket/${bucket}`, {
    headers,
  });
  if (response.ok) return;
  const body = await response.text();
  let error;
  try {
    error = JSON.parse(body);
  } catch {
    error = null;
  }
  const bucketMissing =
    response.status === 404 ||
    error?.code === 'NoSuchBucket' ||
    error?.statusCode === '404';
  if (!bucketMissing) {
    throw new Error(
      `Falha ao consultar o bucket (HTTP ${response.status})` +
        (body ? `: ${body}` : ''),
    );
  }

  const createResponse = await fetch(`${supabaseUrl}/storage/v1/bucket`, {
    method: 'POST',
    headers: { ...headers, 'Content-Type': 'application/json' },
    body: JSON.stringify({ id: bucket, name: bucket, public: true }),
  });
  if (!createResponse.ok && createResponse.status !== 409) {
    const createBody = await createResponse.text();
    throw new Error(
      `Falha ao criar o bucket (HTTP ${createResponse.status})` +
        (createBody ? `: ${createBody}` : ''),
    );
  }
  if (createResponse.status === 409) {
    const verifyResponse = await fetch(
      `${supabaseUrl}/storage/v1/bucket/${bucket}`,
      { headers },
    );
    if (!verifyResponse.ok) {
      const verifyBody = await verifyResponse.text();
      throw new Error(
        `O bucket conflita com um existente, mas não foi possível verificá-lo ` +
          `(HTTP ${verifyResponse.status})` +
          (verifyBody ? `: ${verifyBody}` : ''),
      );
    }
  }
}

async function uploadImage(id) {
  const file = path.join(sourceDirectory, '_imagens', `${id}.png`);
  const image = fs.readFileSync(file);
  const response = await fetch(
    `${supabaseUrl}/storage/v1/object/${bucket}/${id}.png`,
    {
      method: 'POST',
      headers: {
        ...headers,
        'Content-Type': 'image/png',
        'x-upsert': 'true',
      },
      body: image,
    },
  );
  if (!response.ok) {
    const body = await response.text();
    throw new Error(
      `Falha no pictograma ${id} (HTTP ${response.status})` +
        (body ? `: ${body}` : ''),
    );
  }
}

async function main() {
  await ensureBucket();

  let completed = 0;
  let nextIndex = 0;
  const failures = [];
  const workers = Array.from({ length: 6 }, async () => {
    while (nextIndex < ids.length) {
      const id = ids[nextIndex++];
      let error;
      for (let attempt = 1; attempt <= 3; attempt++) {
        try {
          await uploadImage(id);
          completed++;
          if (completed % 250 === 0 || completed === ids.length) {
            console.log(`Enviados ${completed}/${ids.length} pictogramas`);
          }
          error = null;
          break;
        } catch (caught) {
          error = caught;
          await new Promise((resolve) => setTimeout(resolve, attempt * 500));
        }
      }
      if (error) failures.push({ id, message: error.message });
    }
  });

  await Promise.all(workers);
  if (failures.length > 0) {
    console.error(`Falha ao enviar ${failures.length} imagens:`);
    for (const failure of failures.slice(0, 20)) {
      console.error(`${failure.id}: ${failure.message}`);
    }
    process.exitCode = 1;
    return;
  }
  console.log(`Upload concluído: ${ids.length} imagens no bucket ${bucket}.`);
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
