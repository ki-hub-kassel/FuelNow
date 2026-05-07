import { forward } from "../../lib/forward";

export const config = {
    runtime: "edge",
    regions: ["fra1"],
};

export default async function handler(req: Request): Promise<Response> {
    return forward(req, "list.php");
}
