import { IsString, IsNotEmpty } from 'class-validator';

export class AssignUserToProjectDto {
    @IsString()
    @IsNotEmpty()
    papel: string; // O papel que o usuário terá especificamente neste projeto
}