import * as vfs from 'vinyl-fs';
import {TMP_DIR} from '../../config';

export = () => {
  return vfs.src('node_modules', {read: false})
  .pipe(vfs.symlink(TMP_DIR));
};
