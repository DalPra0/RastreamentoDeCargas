// Backend Example - Cloudflare Worker para Correios
// Este é um exemplo de como implementar um backend para conectar com os Correios

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      if (path.startsWith('/correios/')) {
        const trackingCode = path.split('/').pop();
        return await handleCorreios(trackingCode, env, corsHeaders);
      }
      
      return jsonResponse({ error: 'Not found' }, 404, corsHeaders);
    } catch (e) {
      return jsonResponse({ error: String(e) }, 500, corsHeaders);
    }
  }
}

async function handleCorreios(code, env, corsHeaders) {
  // Valida o código dos Correios
  const correiosPattern = /^[A-Z]{2}\d{9}[A-Z]{2}$/;
  if (!correiosPattern.test(code)) {
    return jsonResponse({
      error: 'Código inválido para os Correios'
    }, 400, corsHeaders);
  }

  try {
    // IMPORTANTE: Substitua pela URL real da API dos Correios
    // Esta é uma simulação - você precisa de credenciais reais
    const correiosResponse = await simulateCorreiosAPI(code);
    
    // Converte para o formato esperado pelo app
    const normalizedResponse = {
      carrier: 'correios',
      status: mapCorreiosStatus(correiosResponse.status),
      events: correiosResponse.events.map(event => ({
        date: event.data, // ISO format
        status: mapCorreiosStatus(event.status),
        description: event.descricao,
        location: event.local
      }))
    };

    return jsonResponse(normalizedResponse, 200, corsHeaders);
    
  } catch (error) {
    return jsonResponse({
      error: 'Erro ao consultar os Correios',
      details: error.message
    }, 502, corsHeaders);
  }
}

// Simulação da API dos Correios (substitua pela implementação real)
async function simulateCorreiosAPI(code) {
  // MOCK - Em produção, faça a requisição real para os Correios
  return {
    status: 'objeto_entregue',
    events: [
      {
        data: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
        status: 'objeto_postado',
        descricao: 'Objeto postado',
        local: 'São Paulo, SP'
      },
      {
        data: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
        status: 'objeto_em_transito',
        descricao: 'Objeto em trânsito - origem',
        local: 'São Paulo, SP'
      },
      {
        data: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
        status: 'objeto_saiu_para_entrega',
        descricao: 'Objeto saiu para entrega',
        local: 'Curitiba, PR'
      },
      {
        data: new Date().toISOString(),
        status: 'objeto_entregue',
        descricao: 'Objeto entregue ao destinatário',
        local: 'Curitiba, PR'
      }
    ]
  };
}

function mapCorreiosStatus(correiosStatus) {
  const statusMap = {
    'objeto_postado': 'created',
    'objeto_em_transito': 'inTransit',
    'objeto_saiu_para_entrega': 'outForDelivery',
    'objeto_entregue': 'delivered',
    'objeto_com_problema': 'exception'
  };
  
  return statusMap[correiosStatus] || 'inTransit';
}

function jsonResponse(obj, status = 200, headers = {}) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...headers
    }
  });
}

/* 
EXEMPLO DE USO REAL COM OS CORREIOS:

Para usar a API real dos Correios, você precisará:

1. Contratar o serviço junto aos Correios
2. Obter as credenciais (usuário, senha, token)
3. Implementar a autenticação adequada
4. Fazer requisições para a API oficial

Exemplo de requisição real:

async function fetchCorreiosData(code, credentials) {
  const response = await fetch('https://api.correios.com.br/sro-rastro/v1/objetos/' + code, {
    headers: {
      'Authorization': `Bearer ${credentials.token}`,
      'Content-Type': 'application/json'
    }
  });
  
  if (!response.ok) {
    throw new Error(`Erro dos Correios: ${response.status}`);
  }
  
  return await response.json();
}

*/
