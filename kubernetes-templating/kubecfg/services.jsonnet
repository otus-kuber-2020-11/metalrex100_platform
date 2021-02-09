local kube = import "https://github.com/bitnami-labs/kube-libsonnet/raw/52ba963ca44f7a4960aeae9ee0fbee44726e481f/kube.libsonnet";

local deployment_service(name) = {
  svc: kube.Service(name) {
    target_pod:: $.deploy.spec.template,
    spec+: {
      type: "ClusterIP",
      ports: [
        {name: "grpc", port: 50051, targetPort: 50051}
      ]
    },
  },

  deploy: kube.Deployment(name) {
    apiVersion: "apps/v1",
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            server: kube.Container("server") {
              name: "server",
              resources: {
                requests: {cpu: "100m", memory: "64Mi"},
                limits: {cpu: "200m", memory: "128Mi"}
              },
              ports: [{containerPort: 50051}],
              env_: {PORT: "50051"},
              readinessProbe: {
                exec: {command: ["/bin/grpc_health_probe", "-addr=:50051"]}
              },
              livenessProbe: {
                exec: {command: ["/bin/grpc_health_probe", "-addr=:50051"]}
              },
            },
          },
        },
      },
    },
  },
};

{
  payment: deployment_service("paymentservice"){
    deploy+: {
      spec+: {
        template+: {
          spec+: {
            containers_+: {
              server+: {
                image: "gcr.io/google-samples/microservices-demo/paymentservice:v0.1.3",
              }
            }
          }
        }
      }
    }
  }
}

{
  shipping: deployment_service("shippingservice"){
    deploy+: {
      spec+: {
        template+: {
          spec+: {
            containers_+: {
              server+: {
                image: "gcr.io/google-samples/microservices-demo/shippingservice:v0.1.3",
              }
            }
          }
        }
      }
    }
  }
}