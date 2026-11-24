package br.com.senac.sgsst.config;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.BeansException;
import org.springframework.beans.factory.config.BeanFactoryPostProcessor;
import org.springframework.beans.factory.config.ConfigurableListableBeanFactory;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/**
 * Validação fail-fast da configuração do banco.
 *
 * <p>Motivo: {@code spring.datasource.password=${DB_PASSWORD:}} resolve para string vazia quando
 * a variável não existe. O Spring não aborta — ele tenta conectar com senha vazia, o PostgreSQL
 * recusa e o desenvolvedor recebe uma cascata de {@code UnsatisfiedDependencyException} apontando
 * para o Flyway, o Hikari e o EntityManager, longe da causa real. Remover o default também não
 * resolve: o Spring resolve o placeholder ausente para string vazia silenciosamente.
 *
 * <p>Roda como {@link BeanFactoryPostProcessor} porque precisa acontecer antes de qualquer bean ser
 * instanciado — o {@code flywayInitializer} já teria tentado abrir conexão e falhado primeiro.
 *
 * <p>Além do {@link Environment}, lê diretamente o {@code application-local.properties}: como o
 * {@code spring.config.import} é processado depois deste ponto, o Environment ainda não reflete os
 * valores do arquivo, e validar só por ele daria falso negativo (a URL cairia no default de
 * localhost e a senha vazia passaria batido).
 */
@Component
public class ValidacaoConfiguracaoBanco implements BeanFactoryPostProcessor {

  private static final Logger LOG = LoggerFactory.getLogger(ValidacaoConfiguracaoBanco.class);

  private static final String ARQUIVO_LOCAL = "application-local.properties";

  @Override
  public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory)
      throws BeansException {
    Environment ambiente = beanFactory.getBean(Environment.class);
    Properties local = lerArquivoLocal();

    // O arquivo local tem precedencia sobre o Environment neste ponto, porque o
    // spring.config.import ainda nao foi aplicado quando este post-processor roda.
    String senha = primeiroComTexto(
        local.getProperty("spring.datasource.password"),
        ambiente.getProperty("spring.datasource.password"));

    if (StringUtils.hasText(senha)) {
      return;
    }

    String url =
        primeiroComTexto(
            local.getProperty("spring.datasource.url"),
            ambiente.getProperty("spring.datasource.url"),
            ambiente.getProperty("DB_URL"));

    boolean bancoLocal = url.contains("127.0.0.1") || url.contains("localhost");

    // PostgreSQL local sem senha e uma configuracao plausivel; o Neon exige senha sempre.
    if (bancoLocal) {
      LOG.warn(
          "DB_PASSWORD vazio e o banco aponta para localhost ({}). Prosseguindo; se a "
              + "autenticacao falhar, defina a senha.",
          url);
      return;
    }

    throw new IllegalStateException(
        """

        ============================================================
         CONFIGURACAO DO BANCO INCOMPLETA: falta a senha
        ============================================================
         O Spring tentaria conectar em:
           %s
         ...sem senha, e o servidor recusaria a conexao.

         Como resolver (escolha UMA):

           1) Crie 'application-local.properties' na RAIZ do projeto:

                spring.datasource.url=jdbc:postgresql://SEU_HOST/SEU_BANCO?sslmode=require
                spring.datasource.username=SEU_USUARIO
                spring.datasource.password=SUA_SENHA

              O arquivo e carregado automaticamente e ja esta no .gitignore.

           2) Ou defina a variavel de ambiente DB_PASSWORD.
              O formato esperado esta documentado em '.env.example'.
        ============================================================
        """
            .formatted(url));
  }

  /** Retorna o primeiro valor com texto, ou string vazia. */
  private static String primeiroComTexto(String... valores) {
    for (String v : valores) {
      if (StringUtils.hasText(v)) {
        return v;
      }
    }
    return "";
  }

  /** Le application-local.properties da raiz, se existir. Nunca lanca. */
  private Properties lerArquivoLocal() {
    Properties props = new Properties();
    for (String caminho : new String[] {ARQUIVO_LOCAL, "src/main/resources/" + ARQUIVO_LOCAL}) {
      Path p = Path.of(caminho);
      if (!Files.isRegularFile(p)) {
        continue;
      }
      try (InputStream in = Files.newInputStream(p)) {
        props.load(in);
        LOG.debug("Credenciais lidas de {}", p.toAbsolutePath());
        return props;
      } catch (IOException e) {
        LOG.warn("Nao foi possivel ler {}: {}", p, e.getMessage());
      }
    }
    return props;
  }
}
