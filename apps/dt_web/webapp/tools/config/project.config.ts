import {join} from 'path';
import {SeedConfig} from './seed.config';
import {InjectableDependency} from './seed.config.interfaces';

export class ProjectConfig extends SeedConfig {
  PROJECT_TASKS_DIR = join(process.cwd(), this.TOOLS_DIR, 'tasks', 'project');

  constructor() {
    super();
    this.APP_TITLE = 'Detectino';
    let additional_deps: InjectableDependency[] = [
      // {src: 'jquery/dist/jquery.min.js', inject: 'libs'},
      // {src: 'lodash/lodash.min.js', inject: 'libs'},
    ];

    const seedDependencies = this.NPM_DEPENDENCIES;

    this.NPM_DEPENDENCIES = seedDependencies.concat(additional_deps);

    (<any>this.SYSTEM_CONFIG_DEV.paths)['angular2-jwt'] =
      `${this.APP_BASE}node_modules/angular2-jwt/angular2-jwt`;

  }
}
