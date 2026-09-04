import { Router } from 'express';
import translateRouter from './translateRoute';
import ocrRouter from './ocrRoute';
import testConnectionRouter from './testConnectionRoute';
import downloadRouter from './downloadRoute';

const router = Router();

router.use(translateRouter);
router.use(ocrRouter);
router.use(testConnectionRouter);
router.use(downloadRouter);

export default router;
