describe('App', () => {

  beforeEach(() => {
    // change hash depending on router LocationStrategy
    browser.get('/#/home');
  });


  it('should have a title', () => {
    let subject = browser.getTitle();
    let result  = 'Detectino';
    expect(subject).toEqual(result);
  });

  it('should have `your content here`', () => {
    let subject = element(by.css('div.sample-content')).getText();
    let result  = 'Your Content Here';
    expect(subject).toEqual(result);
  });


});
