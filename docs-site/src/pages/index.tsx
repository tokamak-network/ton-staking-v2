import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';

import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/intro">
            Get Started
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title="Documentation"
      description="TON Staking V3 Documentation - Tokamak Network">
      <HomepageHeader />
      <main>
        <div className="container" style={{padding: '2rem 0'}}>
          <div className="row">
            <div className="col col--4">
              <div className="card" style={{padding: '1rem'}}>
                <h3>Architecture</h3>
                <p>Learn about the V2/V3 staking architecture and distribution mechanisms.</p>
                <Link to="/docs/01_v2_architecture">Read more</Link>
              </div>
            </div>
            <div className="col col--4">
              <div className="card" style={{padding: '1rem'}}>
                <h3>Validator</h3>
                <p>Understand validator registration, rewards, and slashing conditions.</p>
                <Link to="/docs/04_validator">Read more</Link>
              </div>
            </div>
            <div className="col col--4">
              <div className="card" style={{padding: '1rem'}}>
                <h3>RAT Implementation</h3>
                <p>Technical details of Rollup Attestation Token implementation.</p>
                <Link to="/docs/07_rat_implementation">Read more</Link>
              </div>
            </div>
          </div>
        </div>
      </main>
    </Layout>
  );
}
