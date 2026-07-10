import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

const FeatureList = [
  {
    title: 'Production-Ready Examples',
    Svg: require('@site/static/img/undraw_docusaurus_mountain.svg').default,
    description: (
      <>
        Complete, tested Terraform stacks for deploying popular open-source applications on Aruba Cloud.
        Every example includes cloud-init bootstrap, networking, and persistent storage.
      </>
    ),
  },
  {
    title: '50+ Applications',
    Svg: require('@site/static/img/undraw_docusaurus_tree.svg').default,
    description: (
      <>
        CMS, DevOps tools, databases, monitoring, AI/ML platforms, and more.
        From WordPress to Kubernetes — all ready to deploy in minutes with a single{' '}
        <code>terraform apply</code>.
      </>
    ),
  },
  {
    title: 'Modular Architecture',
    Svg: require('@site/static/img/undraw_docusaurus_react.svg').default,
    description: (
      <>
        A shared network module provides consistent VPC, subnet, security groups, and Elastic IP setup.
        Add your application on top without reinventing the infrastructure layer.
      </>
    ),
  },
];

function Feature({Svg, title, description}) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <Svg className={styles.featureSvg} role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
