import { ScrollFeatureTimeline } from '../components/ScrollFeatureTimeline'
import { productFeatures } from '../theme/tokens'

export function FeatureShowcaseSection() {
  return (
    <section id="features" className="section featureSection">
      <div className="container">
        <p className="eyebrow">Product Walkthrough</p>
        <h2>Diese Scroll-Strecke verkauft die App in weniger als einer Minute.</h2>
        <p className="sectionLead">
          Links siehst du das iPhone in Aktion, rechts den konkreten Impact. Jeder Step ist auf
          Conversion optimiert: klar, schnell, sofort nachvollziehbar.
        </p>
      </div>

      <div className="container timelineContainer">
        <ScrollFeatureTimeline features={productFeatures} />
      </div>
    </section>
  )
}
