import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting, HttpTestingController } from '@angular/common/http/testing';
import { EpisService } from './epis.service';
describe('EpisService API', () => {
  beforeEach(() =>
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    }),
  );
  afterEach(() => TestBed.inject(HttpTestingController).verify());
  it('lista estoque real na API 8080', () => {
    const service = TestBed.inject(EpisService);
    service.obterEpis().subscribe((items) => expect(items).toEqual([]));
    TestBed.inject(HttpTestingController).expectOne('http://localhost:8080/api/epis').flush([]);
  });
});
