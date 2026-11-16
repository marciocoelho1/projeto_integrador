package br.com.senac.sgsst.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig implements WebMvcConfigurer {

  private final String[] origens;

  public CorsConfig(
    @Value("${app.cors.origins:http://localhost:4200}") String origens
  ) {
    this.origens = origens.split("\\s*,\\s*");
  }

  @Override
  public void addCorsMappings(CorsRegistry registry){
    registry.addMapping("/api/**")
      .allowedOrigins(origens)
      .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
      .allowedHeaders("*")
      .allowCredentials(false);
  }
}
