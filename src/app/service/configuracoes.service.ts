import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class ConfiguracoesService {
  private apiUrl = 'http://localhost:3000/configuracoes';

  constructor(private http: HttpClient) {}

  
}