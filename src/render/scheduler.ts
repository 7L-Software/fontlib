const RunService = game.GetService("RunService");

export interface Renderable {
	render(hasTime: () => boolean): boolean;
}

const queue: Renderable[] = [];
const queued = new Set<Renderable>();
let connection: RBXScriptConnection | undefined;
let budget = 0.004;

function drain() {
	const started = os.clock();
	const hasTime = () => os.clock() - started < budget;
	const pending = [...queue];
	queue.clear();
	queued.clear();
	for (const item of pending) {
		if (!(hasTime() && item.render(hasTime))) {
			enqueue(item);
		}
	}
	if (queue.isEmpty() && connection) {
		connection.Disconnect();
		connection = undefined;
	}
}

export function enqueue(item: Renderable) {
	if (queued.has(item)) {
		return;
	}
	queued.add(item);
	queue.push(item);
	if (!connection) {
		connection = RunService.Heartbeat.Connect(drain);
	}
}

export function dequeue(item: Renderable) {
	if (queued.delete(item)) {
		queue.remove(queue.indexOf(item));
	}
}

export function setFrameBudget(seconds: number) {
	budget = seconds;
}
