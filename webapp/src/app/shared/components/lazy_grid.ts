import { PageSortFilter } from '../../services/crud';

export class LazyGrid {
  // pagination & sort stuff
  private sortPage: PageSortFilter;
  private totalRecords: number;

  constructor(private loadCb: Function) {
    this.sortPage = new PageSortFilter({
      page: 1, per_page: 10, sort: null, direction: null
    });
    this.totalRecords = 0;
  }

  public getPerPage(): number {
    return this.sortPage.per_page;
  }

  public getSortPage(): PageSortFilter {
    return this.sortPage;
  }

  public getTotalRecords(): number {
    return this.totalRecords;
  }

  public setTotalRecords(t: number): void {
    this.totalRecords = t;
  }

  public getLazy(event) {
    const page = Math.ceil((event.first + event.rows) / event.rows);
    this.sortPage.page = page;
    this.sortPage.per_page = event.rows;

    this.sortPage.sort = event.sortField;
    if (event.sortOrder > 0) {
      this.sortPage.direction = 'asc';
    } else {
      this.sortPage.direction = 'desc';
    }

    this.sortPage.clearFilters();
    for (const key in event.filters) {
      if (event.filters.hasOwnProperty(key)) {
        const value = event.filters[key].value;
        const match = event.filters[key].matchMode;
        this.sortPage.addFilter(key, value, match);
      }
    }

    return this.loadCb();
  }
}
