package br.com.senac.sgsst.dto;

import br.com.senac.sgsst.entity.Colaborador;

public record ColaboradorResponse(
  Integer id,
  String matricula,
  String nome,
  String cpf,
  String email,
  String cargo,
  String setor,
  String status
) {

  public static ColaboradorResponse from(Colaborador colaborador) {
    return new ColaboradorResponse(
      colaborador.getId(),
      colaborador.getMatricula(),
      colaborador.getNome(),
      colaborador.getCpf(),
      colaborador.getEmail(),
      colaborador.getCargo(),
      colaborador.getSetor(),
      colaborador.getStatus()
    );
  }
}
