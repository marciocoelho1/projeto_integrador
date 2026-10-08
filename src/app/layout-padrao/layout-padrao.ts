import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { AuthService } from '../auth.service';

@Component({
  selector: 'app-layout-padrao',
  standalone: true,
  imports: [CommonModule, RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './layout-padrao.html',
  styleUrl: './layout-padrao.scss',
})
export class LayoutPadrao {
  private authService = inject(AuthService);
  private router = inject(Router);

  menuAberto = false;

  get userRole(): string {
    return (this.authService.getRole() || '').toLowerCase();
  }

  toggleMenu(): void {
    this.menuAberto = !this.menuAberto;
  }

  fecharMenu(): void {
    this.menuAberto = false;
  }

  sair(event: Event): void {
    event.preventDefault();
    this.authService.logout();
    void this.router.navigate(['/login']);
  }
}
