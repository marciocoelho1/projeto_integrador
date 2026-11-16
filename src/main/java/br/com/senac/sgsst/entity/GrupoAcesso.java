package br.com.senac.sgsst.entity;

import jakarta.persistence.*;
import java.util.LinkedHashSet;
import java.util.Set;

@Entity
@Table(name = "grupos_acesso", schema = "public")
public class GrupoAcesso {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Integer id;
  public Integer getId() { return id; }
  @Column(name = "nomenclatura", nullable = false, unique = true, length = 120)
  private String nomenclatura;
  public String getNomenclatura() { return nomenclatura; }
  public void setNomenclatura(String value) { this.nomenclatura = value; }
  @Column(name = "finalidade", nullable = false, length = 255)
  private String finalidade;
  public String getFinalidade() { return finalidade; }
  public void setFinalidade(String value) { this.finalidade = value; }
  @ElementCollection(fetch = FetchType.EAGER)
  @CollectionTable(
    name = "grupo_modulos",
    schema = "public",
    joinColumns = @JoinColumn(name = "grupo_id")
  )
  @Column(name = "modulo_chave", nullable = false, length = 40)
  private Set<String> moduloChaves = new LinkedHashSet<>();
  public Set<String> getModuloChaves() { return moduloChaves; }
  public void setModuloChaves(Set<String> value) { this.moduloChaves = value; }
}
