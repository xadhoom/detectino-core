describe('App', () => {

  beforeEach(() => {
    browser.get('/');
  });


  it('should have a title', () => {
    let subject = browser.getTitle();
    let result  = 'Detectino';
    expect(subject).toEqual(result);
  });

  it('should have top menu', () => {
    let subject = element(by.css('app ul#top-menu')).isPresent();
    let result  = true;
    expect(subject).toEqual(result);
  });

  it('should have <router-outlet>', () => {
    let subject = element(by.css('app router-outlet')).isPresent();
    let result  = true;
    expect(subject).toEqual(result);
  });

});
