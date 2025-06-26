import { AuthService } from './firebase-auth.service';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    firebaseLogin(req: any): Promise<import("mongoose").Document<unknown, {}, import("../src/schema/usuario.schema").User, {}> & import("../src/schema/usuario.schema").User & Required<{
        _id: unknown;
    }> & {
        __v: number;
    }>;
}
