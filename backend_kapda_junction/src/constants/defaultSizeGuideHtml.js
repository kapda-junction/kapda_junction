/**
 * Shown when no custom HTML is saved (key: sizeGuideHtml).
 * Designed for flutter_html + TableHtmlExtension on narrow phones:
 * - Light header row (no white-on-navy — th text stays visible)
 * - Max 2 columns per table to avoid horizontal overflow
 */
module.exports = `
<h2>Men's size guide</h2>
<p>
  Typical Indian men’s wear measurements. Between two sizes, choose the larger for comfort.
  <strong>Chest:</strong> fullest part around chest. <strong>Jeans:</strong> at natural waist.
</p>

<h3>Shirts, polos &amp; jackets</h3>
<table>
  <tr><th>Size</th><th>Chest (inches)</th></tr>
  <tr><td>S</td><td>36–38</td></tr>
  <tr><td>M</td><td>38–40</td></tr>
  <tr><td>L</td><td>40–42</td></tr>
  <tr><td>XL</td><td>42–44</td></tr>
  <tr><td>XXL</td><td>44–46</td></tr>
</table>
<p style="font-size:12px;color:#64748B;margin:8px 0 4px;line-height:1.4;">Approx. cm: S 91–97 · M 97–102 · L 102–107 · XL 107–112 · XXL 112–117</p>

<h3>T-shirts (regular)</h3>
<table>
  <tr><th>Size</th><th>Chest (inches)</th></tr>
  <tr><td>S</td><td>36–38</td></tr>
  <tr><td>M</td><td>38–40</td></tr>
  <tr><td>L</td><td>40–42</td></tr>
  <tr><td>XL</td><td>42–44</td></tr>
  <tr><td>XXL</td><td>44–46</td></tr>
</table>

<h3>Jeans &amp; trousers (waist)</h3>
<table>
  <tr><th>Tag</th><th>Waist (in)</th></tr>
  <tr><td>28</td><td>28</td></tr>
  <tr><td>30</td><td>30</td></tr>
  <tr><td>32</td><td>32</td></tr>
  <tr><td>34</td><td>34</td></tr>
  <tr><td>36</td><td>36</td></tr>
  <tr><td>38</td><td>38</td></tr>
</table>

<p style="font-size:13px;color:#64748B;margin:14px 0 0;line-height:1.45;"><strong style="color:#0F172A;">Tip:</strong> Inseam / length varies by style — check the product description.</p>
`.trim();
