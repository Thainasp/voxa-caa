package br.edu.ifsp.voxa.sms;

/** Envio de SMS do botão de emergência. A implementação é escolhida em voxa.sms.provider. */
public interface SmsGateway {

    /** @return true se o provedor aceitou a mensagem. */
    boolean enviar(String telefone, String mensagem);
}
