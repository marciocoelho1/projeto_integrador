import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { environment } from '../../environments/environment';
import {
  Cargo,
  CargoRequest,
  CargoTreinamentoItem,
  Certificacao,
  CertificacaoRequest,
  LntCargo,
  LntColaborador,
  ReciclagemDerivada,
  TurmaReciclagem,
  TurmaReciclagemRequest,
  VinculoRequest,
  VinculoTreinamento,
} from '../models/treinamento-avancado.model';

/** Endpoints da matriz de treinamentos: vínculos, certificações, cargos/LNT, turmas e reciclagens. */
@Injectable({ providedIn: 'root' })
export class TreinamentoAvancadoService {
  private readonly http = inject(HttpClient);
  private readonly url = `${environment.apiBaseUrl}`;

  private comFiltro(chave: string, valor?: number | null) {
    return valor === undefined || valor === null
      ? new HttpParams()
      : new HttpParams().set(chave, String(valor));
  }

  listarVinculos(colaboradorId?: number | null) {
    return this.http.get<VinculoTreinamento[]>(`${this.url}/vinculos`, {
      params: this.comFiltro('colaboradorId', colaboradorId),
    });
  }

  criarVinculo(dados: VinculoRequest) {
    return this.http.post<VinculoTreinamento>(`${this.url}/vinculos`, dados);
  }

  atualizarVinculo(id: number, dados: VinculoRequest) {
    return this.http.put<VinculoTreinamento>(`${this.url}/vinculos/${id}`, dados);
  }

  excluirVinculo(id: number) {
    return this.http.delete<void>(`${this.url}/vinculos/${id}`);
  }

  listarCertificacoes(colaboradorId?: number | null) {
    return this.http.get<Certificacao[]>(`${this.url}/certificacoes`, {
      params: this.comFiltro('colaboradorId', colaboradorId),
    });
  }

  criarCertificacao(dados: CertificacaoRequest) {
    return this.http.post<Certificacao>(`${this.url}/certificacoes`, dados);
  }

  atualizarCertificacao(id: number, dados: CertificacaoRequest) {
    return this.http.put<Certificacao>(`${this.url}/certificacoes/${id}`, dados);
  }

  excluirCertificacao(id: number) {
    return this.http.delete<void>(`${this.url}/certificacoes/${id}`);
  }

  listarCargos() {
    return this.http.get<Cargo[]>(`${this.url}/cargos`);
  }

  criarCargo(dados: CargoRequest) {
    return this.http.post<Cargo>(`${this.url}/cargos`, dados);
  }

  atualizarCargo(id: number, dados: CargoRequest) {
    return this.http.put<Cargo>(`${this.url}/cargos/${id}`, dados);
  }

  excluirCargo(id: number) {
    return this.http.delete<void>(`${this.url}/cargos/${id}`);
  }

  /** Substitui a matriz LNT do cargo (treinamentos obrigatórios). */
  atualizarMatrizCargo(cargoId: number, treinamentos: CargoTreinamentoItem[]) {
    return this.http.put<LntCargo>(`${this.url}/cargos/${cargoId}/treinamentos`, {
      treinamentos: treinamentos.map((item) => ({
        treinamentoId: item.treinamentoId,
        obrigatorio: item.obrigatorio,
      })),
    });
  }

  listarLnt() {
    return this.http.get<LntCargo[]>(`${this.url}/lnt`);
  }

  listarLntColaboradores() {
    return this.http.get<LntColaborador[]>(`${this.url}/lnt/colaboradores`);
  }

  listarTurmasReciclagem(treinamentoId?: number | null) {
    return this.http.get<TurmaReciclagem[]>(`${this.url}/turmas-reciclagem`, {
      params: this.comFiltro('treinamentoId', treinamentoId),
    });
  }

  criarTurmaReciclagem(dados: TurmaReciclagemRequest) {
    return this.http.post<TurmaReciclagem>(`${this.url}/turmas-reciclagem`, dados);
  }

  atualizarTurmaReciclagem(id: number, dados: TurmaReciclagemRequest) {
    return this.http.put<TurmaReciclagem>(`${this.url}/turmas-reciclagem/${id}`, dados);
  }

  excluirTurmaReciclagem(id: number) {
    return this.http.delete<void>(`${this.url}/turmas-reciclagem/${id}`);
  }

  /** Reciclagens derivadas da validade dos vínculos (vencidas ou vencendo em até 60 dias). */
  listarReciclagens() {
    return this.http.get<ReciclagemDerivada[]>(`${this.url}/reciclagens`);
  }
}
