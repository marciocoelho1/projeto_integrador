package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.RelatorioCsv;
import br.com.senac.sgsst.service.RelatorioService;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.nio.charset.StandardCharsets;

/**
 * Relatórios em CSV gerados no servidor. Baixar aqui garante o dado do banco, inclusive quando a
 * tela ainda não carregou a lista completa.
 */
@RestController
@RequestMapping("/api/relatorios")
public class RelatorioController {
  private static final MediaType CSV_UTF8 = MediaType.parseMediaType("text/csv;charset=UTF-8");

  private final RelatorioService service;

  public RelatorioController(RelatorioService service) {
    this.service = service;
  }

  @GetMapping("/dashboard.csv")
  public ResponseEntity<byte[]> dashboard() {
    return arquivo(service.dashboard());
  }

  @GetMapping("/matriz-treinamentos.csv")
  public ResponseEntity<byte[]> matrizTreinamentos() {
    return arquivo(service.matrizTreinamentos());
  }

  @GetMapping("/colaboradores.csv")
  public ResponseEntity<byte[]> colaboradores() {
    return arquivo(service.colaboradores());
  }

  @GetMapping("/epis.csv")
  public ResponseEntity<byte[]> epis() {
    return arquivo(service.epis());
  }

  @GetMapping("/certificacoes.csv")
  public ResponseEntity<byte[]> certificacoes() {
    return arquivo(service.certificacoes());
  }

  @GetMapping("/entregas-epis.csv")
  public ResponseEntity<byte[]> entregasEpi() {
    return arquivo(service.entregasEpi());
  }

  private ResponseEntity<byte[]> arquivo(RelatorioCsv relatorio) {
    HttpHeaders headers = new HttpHeaders();
    headers.setContentType(CSV_UTF8);
    headers.setContentDisposition(
      ContentDisposition.attachment()
        .filename(relatorio.nomeArquivo(), StandardCharsets.UTF_8)
        .build()
    );

    return new ResponseEntity<>(
      relatorio.conteudo().getBytes(StandardCharsets.UTF_8),
      headers,
      HttpStatus.OK
    );
  }
}
