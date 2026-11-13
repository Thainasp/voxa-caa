package br.edu.ifsp.voxa.exception;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.time.OffsetDateTime;
import java.util.List;

/** Corpo padrão de erro de toda a API. */
@RestControllerAdvice
public class GlobalExceptionHandler {

    public record CampoInvalido(String campo, String mensagem) {
    }

    public record ErroResponse(OffsetDateTime timestamp, int status, String erro, String mensagem,
                               String path, List<CampoInvalido> campos) {
    }

    private ResponseEntity<ErroResponse> erro(HttpStatus status, String mensagem, HttpServletRequest req,
                                              List<CampoInvalido> campos) {
        return ResponseEntity.status(status).body(new ErroResponse(OffsetDateTime.now(), status.value(),
                status.getReasonPhrase(), mensagem, req.getRequestURI(), campos));
    }

    @ExceptionHandler(RecursoNaoEncontradoException.class)
    public ResponseEntity<ErroResponse> naoEncontrado(RecursoNaoEncontradoException e, HttpServletRequest req) {
        return erro(HttpStatus.NOT_FOUND, e.getMessage(), req, null);
    }

    @ExceptionHandler(ConflitoException.class)
    public ResponseEntity<ErroResponse> conflito(ConflitoException e, HttpServletRequest req) {
        return erro(HttpStatus.CONFLICT, e.getMessage(), req, null);
    }

    @ExceptionHandler(RegraNegocioException.class)
    public ResponseEntity<ErroResponse> regra(RegraNegocioException e, HttpServletRequest req) {
        return erro(HttpStatus.UNPROCESSABLE_ENTITY, e.getMessage(), req, null);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErroResponse> validacao(MethodArgumentNotValidException e, HttpServletRequest req) {
        List<CampoInvalido> campos = e.getBindingResult().getFieldErrors().stream()
                .map(f -> new CampoInvalido(f.getField(), f.getDefaultMessage()))
                .toList();
        return erro(HttpStatus.BAD_REQUEST, "Dados inválidos", req, campos);
    }

    @ExceptionHandler({HttpMessageNotReadableException.class, MethodArgumentTypeMismatchException.class})
    public ResponseEntity<ErroResponse> corpoInvalido(Exception e, HttpServletRequest req) {
        return erro(HttpStatus.BAD_REQUEST, "Requisição malformada (JSON ou parâmetro inválido)", req, null);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ErroResponse> integridade(DataIntegrityViolationException e, HttpServletRequest req) {
        return erro(HttpStatus.CONFLICT, "Violação de integridade no banco de dados", req, null);
    }
}
