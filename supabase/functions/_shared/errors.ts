/** Porte un code HTTP explicite à travers un throw, pour renvoyer une réponse d'erreur contrôlée (400/413...) plutôt qu'un 400 générique. */
export class HttpError extends Error {
    status: number;
    constructor(status: number, message: string) {
        super(message);
        this.status = status;
    }
}
