import { Model } from 'mongoose';
import { User } from 'src/schema/usuario.schema';
export declare class AuthService {
    private userModel;
    constructor(userModel: Model<User>);
    syncUserWithFirebase(firebaseUser: any): Promise<import("mongoose").Document<unknown, {}, User, {}> & User & Required<{
        _id: unknown;
    }> & {
        __v: number;
    }>;
}
