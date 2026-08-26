---
icon: material/account-eye
hide:
  - toc
---

# 访客分析

访客如何使用本网站——以隐私为先测量。第一方 beacon 记录页面浏览量、站外点击、页面加载时间和 Core Web Vitals；每个事件仅包含页面路径、语言、粗略的设备类别和匿名访客 ID（localStorage——无 cookie）。绝不存储 IP，不收集来源，原始事件在 90 天后过期（DynamoDB TTL）。地理位置来自 CloudFront 请求头，绝不来自访客的 IP。

<div class="metrics-stack" markdown>

<div class="metrics-stat" markdown>

### :material-account-eye: 页面总浏览量

每个页面和语言的累计数据，由指标 API 实时更新。

<span class="metrics-badge metrics-badge--live">实时</span>

<div class="metrics-live" id="metrics-live" hidden>
<div class="metrics-live__stats">
<div class="metrics-live__stat"><b id="metrics-total">–</b><span>总数</span></div>
<div class="metrics-live__stat"><b id="metrics-langs">–</b><span>语言</span></div>
<div class="metrics-live__stat"><b id="metrics-pages">–</b><span>页面</span></div>
</div>

<div class="metrics-live__cols">
<div>
<p class="metrics-live__label">热门页面</p>
<div id="metrics-top"></div>
</div>
<div>
<p class="metrics-live__label">按语言</p>
<div class="metrics-pie-wrap">
<div class="metrics-pie" id="metrics-langs-pie"></div>
<ul class="metrics-pie-legend" id="metrics-langs-legend"></ul>
</div>
</div>
</div>
</div>

</div>

<div class="metrics-stat" markdown>

### :material-earth: 地理位置

按国家/地区统计访客，数据来自生产环境的 CloudFront geo 请求头——管道只保存国家/城市，绝不保存 IP。

<span class="metrics-badge metrics-badge--live">实时</span>

<div class="metrics-live" id="metrics-geo" hidden>
<div class="metrics-pie-wrap">
<div class="metrics-pie" id="metrics-geo-pie"></div>
<ul class="metrics-pie-legend" id="metrics-geo-legend"></ul>
</div>
<div class="metrics-geo-map" id="metrics-geo-map" hidden></div>
<p class="metrics-live__note" id="metrics-geo-note" hidden>等待地理数据——CloudFront 在生产环境接入 API 后，国家/地区数据将自动显示。</p>
</div>

</div>

<div class="metrics-stat" markdown>

<div class="metrics-live__cols" markdown>

<div markdown>

### :material-arrow-top-right: CTA 点击

站外点击——LinkedIn、GitHub、邮件。

<span class="metrics-badge metrics-badge--live">实时</span>

<div class="metrics-live" id="metrics-clicks" hidden>
<div id="metrics-clicks-bars"></div>
</div>

</div>

<div markdown>

### :material-speedometer: Core Web Vitals

LCP、INP、CLS——访客最近一次访问的体验。

<span class="metrics-badge metrics-badge--live">实时</span>

<div class="metrics-live" id="metrics-vitals" hidden>
<div class="metrics-live__stats">
<div class="metrics-live__stat"><div class="pv-vitals-head"><span class="pv-dot pv-dot--warn" id="vitals-lcp-dot"></span><span class="pv-vitals-name">LCP</span></div><b id="vitals-lcp">–</b></div>
<div class="metrics-live__stat"><div class="pv-vitals-head"><span class="pv-dot pv-dot--warn" id="vitals-inp-dot"></span><span class="pv-vitals-name">INP</span></div><b id="vitals-inp">–</b></div>
<div class="metrics-live__stat"><div class="pv-vitals-head"><span class="pv-dot pv-dot--warn" id="vitals-cls-dot"></span><span class="pv-vitals-name">CLS</span></div><b id="vitals-cls">–</b></div>
</div>
</div>

</div>

</div>

</div>

<div class="metrics-stat" markdown>

<div class="metrics-live__cols" markdown>

<div markdown>

### :material-timer-sand: 页面加载时间

平均 TTFB、DOM 就绪和完整加载。

<span class="metrics-badge metrics-badge--live">实时</span>

<div class="metrics-live" id="metrics-timing" hidden>
<div class="metrics-live__stats">
<div class="metrics-live__stat"><b id="timing-ttfb">–</b><span>TTFB</span></div>
<div class="metrics-live__stat"><b id="timing-dcl">–</b><span>DOM 就绪</span></div>
<div class="metrics-live__stat"><b id="timing-load">–</b><span>完整加载</span></div>
</div>
</div>

</div>

<div markdown>

### :material-account-multiple: 访客

通过匿名 localStorage id 统计独立访客——无 cookie。

<span class="metrics-badge metrics-badge--live">实时</span>

<div class="metrics-live" id="metrics-visitors" hidden>
<div class="metrics-live__stats">
<div class="metrics-live__stat"><b id="visitors-unique">–</b><span>独立访客</span></div>
</div>
<div class="metrics-bar__row" id="visitors-ratio-row" hidden>
<span class="metrics-bar__label" id="visitors-new">新访客</span>
<span class="metrics-bar__value" id="visitors-returning">回访</span>
</div>
<div class="pv-ratio" id="visitors-ratio" hidden>
<div class="metrics-bar__fill" id="visitors-new-fill"></div>
<div class="pv-ratio__ret" id="visitors-ret-fill"></div>
</div>
</div>

</div>

</div>

</div>

<div class="metrics-stat" markdown>

### :material-layers: 会话

每次访问的互动深度——30 分钟无操作即结束会话。

<span class="metrics-badge metrics-badge--live">实时</span>

<div class="metrics-live" id="metrics-sessions" hidden>
<div class="metrics-live__stats">
<div class="metrics-live__stat"><b id="sessions-count">–</b><span>会话</span></div>
<div class="metrics-live__stat"><b id="sessions-pages">–</b><span>每次会话页数</span></div>
<div class="metrics-live__stat"><b id="sessions-duration">–</b><span>平均时长</span></div>
<div class="metrics-live__stat"><b id="sessions-bounce">–</b><span>跳出率</span></div>
</div>
</div>

</div>

<div class="metrics-stat" markdown>

### :material-heart-pulse: 可用性

对在线站点的可用性检查，以30天滚动平均值报告。

<span class="metrics-badge">计划中</span>

</div>

<div class="metrics-stat" markdown>

### :material-gauge: 性能

性能预算——每次发布的构建时检查。

<span class="metrics-badge">计划中</span>

</div>

</div>

[返回站点指标 :material-chart-line:](../){ .md-button }
