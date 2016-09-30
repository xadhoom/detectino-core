import { Injectable } from '@angular/core';
import { Http, Response, Request, RequestMethod, Headers } from '@angular/http';
import { AuthHttp } from 'angular2-jwt';

import { Observable } from 'rxjs/Observable';
import { of } from 'rxjs/observable/of';
import 'rxjs/add/operator/catch';

import { PartitionScenario } from '../models/partitionScenario';
import { Crud } from './crud';

@Injectable()
export class PartitionScenarioService extends Crud {

  private baseurl = 'api/scenarios';

  constructor(protected http: AuthHttp) {
    super(http);
  }

  getUrl(id: number) {
    return `${this.baseurl}/${id}/partitions_scenarios`;
  }

  all(id: number): Observable<PartitionScenario[]> {
    return this._read(this.getUrl(id));
  }

  destroy(id: number, s: PartitionScenario): Observable<PartitionScenario> {
    return this._destroy(s, this.getUrl(id));
  }

  save(id: number, s: PartitionScenario): Observable<PartitionScenario> {
    return this._save(s, this.getUrl(id));
  }

}

