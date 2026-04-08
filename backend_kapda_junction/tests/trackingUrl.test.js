const { buildPublicTrackingUrl } = require('../src/utils/trackingUrl');

describe('buildPublicTrackingUrl', () => {
  const prev = process.env.INDIA_POST_TRACK_URL_TEMPLATE;
  afterAll(() => {
    if (prev === undefined) delete process.env.INDIA_POST_TRACK_URL_TEMPLATE;
    else process.env.INDIA_POST_TRACK_URL_TEMPLATE = prev;
  });

  test('returns null when no awb', () => {
    expect(buildPublicTrackingUrl('India Post', '', '')).toBeNull();
  });

  test('uses override URL when http provided', () => {
    expect(
      buildPublicTrackingUrl('India Post', 'ABC123', 'https://example.com/track?id=1')
    ).toBe('https://example.com/track?id=1');
  });

  test('builds India Post style URL with template placeholder', () => {
    process.env.INDIA_POST_TRACK_URL_TEMPLATE = 'https://track.test/?n={awb}';
    expect(buildPublicTrackingUrl('India Post', 'AB 123', '')).toBe(
      'https://track.test/?n=AB%20123'
    );
  });
});
