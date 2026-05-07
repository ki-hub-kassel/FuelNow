import { ScrollFeatureTimeline } from '../components/ScrollFeatureTimeline'
import { productFeatures } from '../theme/tokens'

export function FeatureShowcaseSection() {
  return (
    <section id="features" className="section featureSection">
      <div className="container">
        <p className="eyebrow">Funktions-Walkthrough</p>
        <h2>Ein Device links, 4 Schritte rechts.</h2>
      </div>

      <div className="container timelineContainer">
        <ScrollFeatureTimeline features={productFeatures} />
      </div>
    </section>
  )
}
