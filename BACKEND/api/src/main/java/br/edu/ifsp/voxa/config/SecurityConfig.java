package br.edu.ifsp.voxa.config;

import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jose.jws.SignatureAlgorithm;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.web.client.RestTemplate;

import java.util.Set;

@Configuration
public class SecurityConfig {

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
                .csrf(csrf -> csrf.disable())
                .cors(Customizer.withDefaults())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(authorize -> authorize
                        .requestMatchers(
                                "/api/v1/pranchas/**",
                                "/api/v1/cartoes/**",
                                "/api/v1/usuarios/**",
                                "/api/v1/perfis/**").authenticated()
                        .anyRequest().permitAll())
                .oauth2ResourceServer(resourceServer -> resourceServer.jwt(Customizer.withDefaults()))
                .build();
    }

    @Bean
    JwtDecoder jwtDecoder(
            @Value("${voxa.security.supabase-url:}") String supabaseUrl,
            @Value("${voxa.security.supabase-jwt-secret:}") String jwtSecret,
            @Value("${voxa.security.supabase-anon-key:}") String supabaseAnonKey) {
        if (!jwtSecret.isBlank()) {
            NimbusJwtDecoder decoder = NimbusJwtDecoder.withSecretKey(
                    new SecretKeySpec(jwtSecret.getBytes(java.nio.charset.StandardCharsets.UTF_8), "HmacSHA256"))
                    .macAlgorithm(MacAlgorithm.HS256)
                    .build();
            if (!supabaseUrl.isBlank()) {
                decoder.setJwtValidator(JwtValidators.createDefaultWithIssuer(supabaseUrl.replaceAll("/+$", "") + "/auth/v1"));
            }
            return decoder;
        }
        if (!supabaseUrl.isBlank()) {
            String issuer = supabaseUrl.replaceAll("/+$", "") + "/auth/v1";
            RestTemplate restTemplate = new RestTemplate();
            if (!supabaseAnonKey.isBlank()) {
                restTemplate.getInterceptors().add((request, body, execution) -> {
                    request.getHeaders().set("apikey", supabaseAnonKey);
                    return execution.execute(request, body);
                });
            }
            NimbusJwtDecoder decoder = NimbusJwtDecoder
                    .withJwkSetUri(issuer + "/.well-known/jwks.json")
                    .restOperations(restTemplate)
                    .jwsAlgorithms(algorithms -> algorithms.addAll(
                            Set.of(SignatureAlgorithm.ES256, SignatureAlgorithm.RS256)))
                    .build();
            decoder.setJwtValidator(JwtValidators.createDefaultWithIssuer(issuer));
            return decoder;
        }
        return token -> {
            throw new JwtException("Configure SUPABASE_URL ou SUPABASE_JWT_SECRET para validar tokens.");
        };
    }
}
