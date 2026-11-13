package br.edu.ifsp.voxa.sms;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * SMS simulado (padrão): registra no console. Usado na demonstração e nos
 * testes, sem custo e sem credenciais de operadora.
 */
@Component
@ConditionalOnProperty(name = "voxa.sms.provider", havingValue = "log", matchIfMissing = true)
public class LogSmsGateway implements SmsGateway {

    private static final Logger log = LoggerFactory.getLogger(LogSmsGateway.class);

    @Override
    public boolean enviar(String telefone, String mensagem) {
        log.warn("[SMS SIMULADO] para {}: {}", telefone, mensagem);
        return true;
    }
}
