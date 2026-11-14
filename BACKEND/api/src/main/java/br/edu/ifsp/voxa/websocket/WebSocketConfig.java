package br.edu.ifsp.voxa.websocket;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

/**
 * Servidor WebSocket com STOMP.
 * - Handshake: /ws (WebSocket nativo e fallback SockJS)
 * - Envio: /app/** (ex.: /app/alerta)
 * - Inscrição: /topic/** (ex.: /topic/alertas/{perfilId}) e /user/queue/erros
 */
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Value("${voxa.cors.allowed-origins:*}")
    private String[] allowedOrigins;

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // Permite conexão WebSocket pura (ws://.../ws)
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns(allowedOrigins);

        // Permite conexão via SockJS (http://.../ws) usada pelo stomp_dart_client e
        // painel web
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns(allowedOrigins)
                .withSockJS();
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/topic", "/queue");
        registry.setApplicationDestinationPrefixes("/app");
        registry.setUserDestinationPrefix("/user");
    }
}