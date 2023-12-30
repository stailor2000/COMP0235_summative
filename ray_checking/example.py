import ray

# Connect to the existing Ray cluster
ray.init(address='auto')

@ray.remote
def square(x):
    return x * x


if __name__ == '__main__':
    n = 10000
    # NOTE: this is a future. It is a computation that hasn't happened yet
    futures = [square.remote(i) for i in range(n)]
    results = ray.get(futures)

    print(results[:5])
