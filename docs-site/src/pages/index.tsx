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
        <div style={{
          background: '#ff9800',
          color: '#000',
          padding: '0.5rem 1rem',
          borderRadius: '4px',
          marginBottom: '1rem',
          fontWeight: 'bold',
        }}>
          WARNING: This documentation is for development version
        </div>
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
                <h3>System Overview</h3>
                <p>Learn about the V3 staking system overview and core concepts.</p>
                <Link to="/docs/01-system-overview">Read more</Link>
              </div>
            </div>
            <div className="col col--4">
              <div className="card" style={{padding: '1rem'}}>
                <h3>System Architecture</h3>
                <p>Understand the overall architecture and contract dependencies.</p>
                <Link to="/docs/02-system-architecture">Read more</Link>
              </div>
            </div>
            <div className="col col--4">
              <div className="card" style={{padding: '1rem'}}>
                <h3>Actors</h3>
                <p>Learn about sequencer/validator journey and interactions.</p>
                <Link to="/docs/05-actors">Read more</Link>
              </div>
            </div>
          </div>
        </div>
      </main>
    </Layout>
  );
}
