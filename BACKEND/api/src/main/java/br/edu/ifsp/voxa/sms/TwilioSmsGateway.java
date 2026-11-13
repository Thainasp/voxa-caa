package br.edu.ifsp.voxa.sms;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

/**
 * Envio real via API REST da Twilio (voxa.sms.provider=twilio).
 * Na conta de teste da Twilio só é possível enviar para números verificados.
 */
@Component
@ConditionalOnProperty(name = "voxa.sms.provider", havingValue = "twilio")
public class TwilioSmsGateway implements SmsGateway {

    private static final Logger log = LoggerFactory.getLogger(TwilioSmsGateway.class);

    private final RestClient client;
    private final String accountSid;
    private final String fromNumber;

    public TwilioSmsGateway(@Value("${voxa.sms.twilio.account-sid}") String accountSid,
                            @Value("${voxa.sms.twilio.auth-token}") String authToken,
                            @Value("${voxa.sms.twilio.from-number}") String fromNumber) {
        this.accountSid = accountSid;
        this.fromNumber = fromNumber;
        this.client = RestClient.builder()
                .baseUrl("https://api.twilio.com/2010-04-01")
                .defaultHeaders(h -> h.setBasicAuth(accountSid, authToken))
                .build();
    }

    @Override
    public boolean enviar(String telefone, String mensagem) {
        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("To", paraE164(telefone));
        form.add("From", fromNumber);
        form.add("Body", mensagem);
        try {
            client.post()
                    .uri("/Accounts/{sid}/Messages.json", accountSid)
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(form)
                    .retrieve()
                    .toBodilessEntity();
            return true;
        } catch (RestClientException e) {
            log.error("Falha ao enviar SMS pela Twilio: {}", e.getMessage());
            return false;
        }
    }

    /** "(11) 99999-9999" -> "+5511999999999" */
    static String paraE164(String telefone) {
        String digitos = telefone.replaceAll("\\D", "");
        if (telefone.trim().startsWith("+")) return "+" + digitos;
        if (digitos.length() == 10 || digitos.length() == 11) return "+55" + digitos;
        return "+" + digitos;
    }
}
