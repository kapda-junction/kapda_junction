/**
 * Shown when no custom HTML is saved in Settings (key: sizeGuideHtml).
 * Safe for flutter_html: simple tags + inline styles only.
 */
module.exports = `
<h2 style="margin:0 0 8px 0;font-size:18px;color:#0F172A;">Men's size guide</h2>
<p style="margin:0 0 14px 0;font-size:14px;color:#64748B;line-height:1.5;">
  Sizes below are typical for Indian men's wear. If you are between two sizes, pick the larger one for comfort.
  For shirts, measure around the fullest part of your chest; for jeans, measure around your natural waist.
</p>

<h3 style="margin:18px 0 8px 0;font-size:16px;color:#0F172A;">Shirts, polos &amp; jackets (chest)</h3>
<table style="width:100%;border-collapse:collapse;font-size:14px;margin-bottom:8px;">
  <tr style="background:#0F172A;color:#FFFFFF;">
    <th style="border:1px solid #CBD5E1;padding:10px 8px;text-align:left;">Size</th>
    <th style="border:1px solid #CBD5E1;padding:10px 8px;text-align:left;">Chest (in)</th>
    <th style="border:1px solid #CBD5E1;padding:10px 8px;text-align:left;">Chest (cm)</th>
  </tr>
  <tr><td style="border:1px solid #E2E8F0;padding:8px;">S</td><td style="border:1px solid #E2E8F0;padding:8px;">36–38</td><td style="border:1px solid #E2E8F0;padding:8px;">91–97</td></tr>
  <tr style="background:#F8FAFC;"><td style="border:1px solid #E2E8F0;padding:8px;">M</td><td style="border:1px solid #E2E8F0;padding:8px;">38–40</td><td style="border:1px solid #E2E8F0;padding:8px;">97–102</td></tr>
  <tr><td style="border:1px solid #E2E8F0;padding:8px;">L</td><td style="border:1px solid #E2E8F0;padding:8px;">40–42</td><td style="border:1px solid #E2E8F0;padding:8px;">102–107</td></tr>
  <tr style="background:#F8FAFC;"><td style="border:1px solid #E2E8F0;padding:8px;">XL</td><td style="border:1px solid #E2E8F0;padding:8px;">42–44</td><td style="border:1px solid #E2E8F0;padding:8px;">107–112</td></tr>
  <tr><td style="border:1px solid #E2E8F0;padding:8px;">XXL</td><td style="border:1px solid #E2E8F0;padding:8px;">44–46</td><td style="border:1px solid #E2E8F0;padding:8px;">112–117</td></tr>
</table>

<h3 style="margin:18px 0 8px 0;font-size:16px;color:#0F172A;">T-shirts (relaxed / regular)</h3>
<table style="width:100%;border-collapse:collapse;font-size:14px;margin-bottom:8px;">
  <tr style="background:#0F172A;color:#FFFFFF;">
    <th style="border:1px solid #CBD5E1;padding:10px 8px;text-align:left;">Size</th>
    <th style="border:1px solid #CBD5E1;padding:10px 8px;text-align:left;">Chest (in)</th>
  </tr>
  <tr><td style="border:1px solid #E2E8F0;padding:8px;">S</td><td style="border:1px solid #E2E8F0;padding:8px;">36–38</td></tr>
  <tr style="background:#F8FAFC;"><td style="border:1px solid #E2E8F0;padding:8px;">M</td><td style="border:1px solid #E2E8F0;padding:8px;">38–40</td></tr>
  <tr><td style="border:1px solid #E2E8F0;padding:8px;">L</td><td style="border:1px solid #E2E8F0;padding:8px;">40–42</td></tr>
  <tr style="background:#F8FAFC;"><td style="border:1px solid #E2E8F0;padding:8px;">XL</td><td style="border:1px solid #E2E8F0;padding:8px;">42–44</td></tr>
  <tr><td style="border:1px solid #E2E8F0;padding:8px;">XXL</td><td style="border:1px solid #E2E8F0;padding:8px;">44–46</td></tr>
</table>

<h3 style="margin:18px 0 8px 0;font-size:16px;color:#0F172A;">Jeans &amp; trousers (waist)</h3>
<table style="width:100%;border-collapse:collapse;font-size:14px;margin-bottom:8px;">
  <tr style="background:#0F172A;color:#FFFFFF;">
    <th style="border:1px solid #CBD5E1;padding:10px 8px;text-align:left;">Jeans size</th>
    <th style="border:1px solid #CBD5E1;padding:10px 8px;text-align:left;">Waist (in)</th>
  </tr>
  <tr><td style="border:1px solid #E2E8F0;padding:8px;">28</td><td style="border:1px solid #E2E8F0;padding:8px;">28</td></tr>
  <tr style="background:#F8FAFC;"><td style="border:1px solid #E2E8F0;padding:8px;">30</td><td style="border:1px solid #E2E8F0;padding:8px;">30</td></tr>
  <tr><td style="border:1px solid #E2E8F0;padding:8px;">32</td><td style="border:1px solid #E2E8F0;padding:8px;">32</td></tr>
  <tr style="background:#F8FAFC;"><td style="border:1px solid #E2E8F0;padding:8px;">34</td><td style="border:1px solid #E2E8F0;padding:8px;">34</td></tr>
  <tr><td style="border:1px solid #E2E8F0;padding:8px;">36</td><td style="border:1px solid #E2E8F0;padding:8px;">36</td></tr>
  <tr style="background:#F8FAFC;"><td style="border:1px solid #E2E8F0;padding:8px;">38</td><td style="border:1px solid #E2E8F0;padding:8px;">38</td></tr>
</table>

<p style="margin:16px 0 0 0;font-size:13px;color:#64748B;line-height:1.5;">
  <strong style="color:#0F172A;">Tip:</strong> Length (inseam) can vary by style — refer to the product description for outseam / length where mentioned.
</p>
`.trim();
