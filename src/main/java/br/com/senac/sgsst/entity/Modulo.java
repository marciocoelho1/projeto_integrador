package br.com.senac.sgsst.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "modulos", schema = "public")
public class Modulo {
  @Id
  @Column(name = "chave", length = 40)
  private String chave;
  public String getChave() { return chave; }
  public void setChave(String value) { this.chave = value; }
  @Column(name = "titulo", nullable = false, length = 120)
  private String titulo;
  public String getTitulo() { return titulo; }
  public void setTitulo(String value) { this.titulo = value; }
  @Column(name = "detalhe", nullable = false, length = 255)
  private String detalhe;
  public String getDetalhe() { return detalhe; }
  public void setDetalhe(String value) { this.detalhe = value; }
}
