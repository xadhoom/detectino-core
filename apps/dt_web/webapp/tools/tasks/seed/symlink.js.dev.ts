import * as vfs from 'vinyl-fs';
import {APP_DEST} from '../../config';

export = () => {
  return vfs.src('node_modules', {read: false})
  .pipe(vfs.symlink(APP_DEST));
};
