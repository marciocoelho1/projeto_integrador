export type StatusColaborador = 'Ativo' | 'Inativo' | 'Afastado';

export interface ColaboradorRequest {
    matricula: string;
    nome: string;
    cpf: string;
    email: string;
    cargo: string;
    setor: string;
    status: StatusColaborador;
}

export interface Colaborador extends ColaboradorRequest {
    id: number;
}